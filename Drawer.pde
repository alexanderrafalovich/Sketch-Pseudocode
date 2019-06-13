class Drawer{
  float _posX;
  float _posY;
  float _friction;
  float _mass;
  float _minX;
  float _minY;
  float _maxX;
  float _maxY;
  
  float velocityX = 0.0;
  float velocityY = 0.0;
  
  
  Drawer(float posX,float posY,float friction, float mass, float minX, float minY, float maxX, float maxY){
    _posX = posX;
    _posY = posY;
    _friction = friction;
    _mass = mass;
    _minX = minX;
    _minY = minY;
    _maxX = maxX;
    _maxY = maxY;
  }
  
  void ApplyForce(float forceX, float forceY){
    float accelerationX = forceX/_mass;
    float accelerationY = forceY/_mass;
     velocityX += accelerationX;
     velocityY += accelerationY;
  }
  
  void UpdatePosition(){
    float speed = sqrt(velocityX*velocityX + velocityY * velocityY);

    float ratioX = velocityX/speed;
    float ratioY = velocityY/speed;
    speed = speed - _friction*speed*speed;      
    velocityX = ratioX* speed;
    velocityY = ratioY* speed;
    
    if(velocityX>0 && _posX>_maxX){
      _posX = _minX;
    }else if(velocityX<0 && _posX<_minX){
      _posX = _maxX;
    }
    if(velocityY>0 &&_posY>_maxY){
      _posY = _minY;
    }else if(velocityY<0 && _posY<_minY){
      _posY = _maxY;
    }
    
    _posX += velocityX;
    _posY += velocityY;
  }
  
  void Reset(){
    velocityX = 0.0;
    velocityY = 0.0;
  }
}
