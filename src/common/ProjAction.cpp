/*
 *  ProjAction.cpp
 *  OpenLieroX
 *
 *  Created by Albert Zeyer on 02.04.09.
 *  code under LGPL
 *
 */

#include "ProjAction.h"
#include "CGameScript.h"
#include "CWorm.h"
#include "CProjectile.h"
#include "CClient.h"
#include "ProjectileDesc.h"
#include "Physics.h"
#include "ConfigHandler.h"
#include "EndianSwap.h"

int Proj_SpawnParent::ownerWorm() const {
	switch(type) {
		case PSPT_NOTHING: return -1;
		case PSPT_SHOT: return shot->nWormID;
		case PSPT_PROJ: return proj->GetOwner(); 
	}
	return -1;
}

int Proj_SpawnParent::fixedRandomIndex() const {
	switch(type) {
		case PSPT_NOTHING: return -1;
		case PSPT_SHOT: return shot->nRandom;
		case PSPT_PROJ: return proj->getRandomIndex() + 1; 
	}
	return -1;	
}

float Proj_SpawnParent::fixedRandomFloat() const {
	switch(type) {
		case PSPT_NOTHING: return -1;
		case PSPT_SHOT: return GetFixedRandomNum(shot->nRandom);
		case PSPT_PROJ: return proj->getRandomFloat(); 
	}
	return -1;	
}

CVec Proj_SpawnParent::position() const {
	switch(type) {
		case PSPT_NOTHING: return CVec(0,0);
		case PSPT_SHOT: {
			CVec dir;
			GetVecsFromAngle(shot->nAngle, &dir, NULL);
			CVec pos = shot->cPos + dir*8;
			return pos;
		}
		case PSPT_PROJ: return proj->GetPosition(); 
	}
	return CVec(0,0);
}

CVec Proj_SpawnParent::velocity() const {
	switch(type) {
		case PSPT_NOTHING: return CVec(0,0);
		case PSPT_SHOT: return shot->cWormVel;
		case PSPT_PROJ: return proj->GetVelocity(); 
	}
	return CVec(0,0);
}

float Proj_SpawnParent::angle() const {
	switch(type) {
		case PSPT_NOTHING: return 0;
		case PSPT_SHOT: return (float)shot->nAngle;
		case PSPT_PROJ: {
			CVec v = velocity();
			NormalizeVector(&v);
			float heading = (float)( -atan2(v.x,v.y) * (180.0f/PI) );
			heading+=90;
			FMOD(heading, 360.0f);
			return heading;
		}
	}
	return 0;
}



void Proj_SpawnInfo::apply(Proj_SpawnParent parent, AbsTime spawnTime) const {
	// Calculate the angle of the direction the projectile is heading
	float heading = 0;
	if(Useangle)
		heading = parent.angle();
	
	for(int i=0; i < Amount; i++) {		
		CVec sprd;
		if(UseParentVelocityForSpread)
			sprd = parent.velocity() * ParentVelSpreadFactor;
		else {
			int a = (int)( (float)Angle + heading + parent.fixedRandomFloat() * (float)Spread );
			GetVecsFromAngle(a, &sprd, NULL);
		}
		
		int rot = 0;
		if(UseRandomRot) {
			// Calculate a random starting angle for the projectile rotation (if used)
			if(Proj->Rotating) {
				// Prevent div by zero
				if(Proj->RotIncrement == 0)
					Proj->RotIncrement = 1;
				rot = GetRandomInt( 360 / Proj->RotIncrement ) * Proj->RotIncrement;
			}
		}
		
		if(parent.type == Proj_SpawnParent::PSPT_SHOT) {
			parent.shot->nRandom++;
			parent.shot->nRandom %= 255;		
		}
		
		CVec v = sprd * (float)Speed;
		CVec speedVarVec = sprd;
		if(UseSpecial11VecForSpeedVar) speedVarVec = CVec(1,1);
		v += speedVarVec * (float)SpeedVar * parent.fixedRandomFloat();
		if(AddParentVel)
			v += ParentVelFactor * parent.velocity();
		
		if(parent.type == Proj_SpawnParent::PSPT_SHOT) {
			parent.shot->nRandom *= 5;
			parent.shot->nRandom %= 255;		
		}		
		
		AbsTime ignoreWormCollBeforeTime = spawnTime;
		if(parent.type == Proj_SpawnParent::PSPT_PROJ)
			ignoreWormCollBeforeTime = parent.proj->getIgnoreWormCollBeforeTime();
		else
			// we set the ignoreWormCollBeforeTime to the current time to let the physics engine
			// first emulate the projectiles to the curtime and ignore earlier colls as the worm-pos
			// is probably outdated at this time
			ignoreWormCollBeforeTime = GetPhysicsTime() + 0.1f; // HINT: we add 100ms (it was dt before) because the projectile is spawned -> worms are simulated (pos change) -> projectiles are simulated
		
		int random = parent.fixedRandomIndex();

		cClient->SpawnProjectile(parent.position(), v, rot, parent.ownerWorm(), Proj, random, spawnTime, ignoreWormCollBeforeTime);

		if(parent.type == Proj_SpawnParent::PSPT_SHOT) {
			parent.shot->nRandom++;
			parent.shot->nRandom %= 255;		
		}		
	}
	
}


void Proj_Action::applyTo(const ProjCollisionType* colType, CProjectile* prj, Proj_DoActionInfo* info) const {
	switch (Type)  {
			// Explosion
		case PJ_EXPLODE:
			info->explode = true;
			
			if(Shake > info->shake)
				info->shake = Shake;
			
			// Play the hit sound
			if(UseSound)
				info->playSound = true;
			break;
			
			// Bounce
		case PJ_BOUNCE:
			prj->Bounce(BounceCoeff);
			
			// Do we do a bounce-explosion (bouncy larpa uses this)
			if(BounceExplode > 0)
				cClient->Explosion(prj->GetPosition(), BounceExplode, false, prj->GetOwner());
			break;
			
			// Carve
		case PJ_CARVE: 
			if(colType && !colType->withWorm) {
				int d = cClient->getMap()->CarveHole(Damage, prj->GetPosition());
				info->deleteAfter = true;
				
				// Increment the dirt count
				if(prj->hasOwner())
					cClient->getRemoteWorms()[prj->GetOwner()].incrementDirtCount( d );
			}
			break;
			
			// Dirt
		case PJ_DIRT:
			info->dirt = true;
			break;
			
			// Green Dirt
		case PJ_GREENDIRT:
			info->grndirt = true;
			break;
			
		case PJ_INJURE:
			if(colType && colType->withWorm) {
				info->deleteAfter = true;
				cClient->InjureWorm(&cClient->getRemoteWorms()[colType->wormId], Damage, prj->GetOwner());
				break;
			}
			
		case PJ_DISAPPEAR:
			// TODO: do something special?
		case PJ_NOTHING:
			// if Hit_Type == PJ_NOTHING, it means that this projectile goes through all walls
			if(colType && !colType->withWorm && colType->colMask & PJC_MAPBORDER) {
				// HINT: This is new since Beta9. I hope it doesn't change any serious behaviour.
				info->deleteAfter = true;
			}
			break;
			
		case __PJ_LBOUND: case __PJ_UBOUND: errors << "Proj_Action::applyTo: hit __PJ_BOUND" << endl;
	}
	
	if(Projectiles) {
		info->spawnprojectiles = true;
		info->spawnInfo = &Proj;
	}
	
}




static void projectile_doExplode(CProjectile* const prj, int shake) {
	const proj_t *pi = prj->GetProjInfo();
	// Explosion
	int damage = pi->Hit.Damage;
	if(pi->PlyHit.Type == PJ_EXPLODE)
		damage = pi->PlyHit.Damage;

	if(damage != -1) // TODO: why only with -1?
		cClient->Explosion(prj->GetPosition(), damage, shake, prj->GetOwner());
}

static void projectile_doTimerExplode(CProjectile* const prj, int shake) {
	const proj_t *pi = prj->GetProjInfo();
	// Explosion
	int damage = pi->Timer.Damage;
	if(pi->PlyHit.Type == PJ_EXPLODE)
		damage = pi->PlyHit.Damage;

	if(damage != -1) // TODO: why only with -1?
		cClient->Explosion(prj->GetPosition(), damage, shake, prj->GetOwner());
}

static void projectile_doProjSpawn(CProjectile* const prj, const Proj_SpawnInfo* spawnInfo, AbsTime fSpawnTime) {
	spawnInfo->apply(prj, fSpawnTime);
}

static void projectile_doMakeDirt(CProjectile* const prj) {
	int damage = 5;
	int d = 0;
	d += cClient->getMap()->PlaceDirt(damage,prj->GetPosition()-CVec(6,6));
	d += cClient->getMap()->PlaceDirt(damage,prj->GetPosition()+CVec(6,-6));
	d += cClient->getMap()->PlaceDirt(damage,prj->GetPosition()+CVec(0,6));

	// Remove the dirt count on the worm
	if(prj->hasOwner())
		cClient->getRemoteWorms()[prj->GetOwner()].incrementDirtCount( -d );
}

static void projectile_doMakeGreenDirt(CProjectile* const prj) {
	int d = cClient->getMap()->PlaceGreenDirt(prj->GetPosition());

	// Remove the dirt count on the worm
	if(prj->hasOwner())
		cClient->getRemoteWorms()[prj->GetOwner()].incrementDirtCount( -d );
}


void Proj_DoActionInfo::execute(CProjectile* const prj, const AbsTime currentTime) {
	const proj_t *pi = prj->GetProjInfo();
	
	// Explode?
	if(explode) {
		if(!timer)
			projectile_doExplode(prj, shake);
		else
			projectile_doTimerExplode(prj, shake);
		deleteAfter = true;
	}

	// Dirt
	if(dirt) {
		projectile_doMakeDirt(prj);
		deleteAfter = true;
	}

	// Green dirt
	if(grndirt) {
		projectile_doMakeGreenDirt(prj);
		deleteAfter = true;
	}

	if(trailprojspawn) {
		// we use prj->fLastSimulationTime here to simulate the spawing at the current simulation time of this projectile
		projectile_doProjSpawn( prj, &pi->Trail.Proj, prj->fLastSimulationTime );
	}

	// Spawn any projectiles?
	if(spawnprojectiles) {
		if(!spawnInfo || !spawnInfo->isSet())
			spawnInfo = &pi->GeneralSpawnInfo;
		// we use currentTime (= the simulation time of the cClient) to simulate the spawing at this time
		// because the spawing is caused probably by conditions of the environment like collision with worm/cClient->getMap()
		projectile_doProjSpawn(prj, spawnInfo, currentTime);
	}

	if(playSound) {
		PlaySoundSample(pi->smpSample);		
	}
	
	// HINT: delete "junk projectiles" - projectiles that have no action assigned and are therefore never destroyed
	// Some bad-written mods contain those projectiles and they make the game more and more laggy (because new and new
	// projectiles are spawned and never destroyed) and prevent more important projectiles from spawning.
	// These conditions test for those projectiles and remove them
	if (!pi->Hit.hasAction() && !pi->PlyHit.hasAction() && !pi->Timer.hasAction()) // Isn't destroyed by any event
		if (!pi->Animating || (pi->Animating && (pi->AnimType != ANI_ONCE || pi->bmpImage == NULL))) // Isn't destroyed after animation ends
			if (!pi->Hit.Projectiles && !pi->PlyHit.Projectiles && !pi->Timer.Projectiles)  // Doesn't spawn any projectiles
				deleteAfter = true;

	if(deleteAfter) {
		prj->setUnused();
	}
	
}

