import ketai.data.*;
import ketai.sensors.*;

KetaiSensor sensor;
KetaiSQLite db;
Boolean isCapturing = false;
ArrayList<Double> S = new ArrayList();
ArrayList<Integer> candidatos = new ArrayList();
static int K = 10;
int indice = K;
String CREATE_DB_SQL = "CREATE TABLE data ( time INTEGER PRIMARY KEY, x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL);";

void setup()
{

  fullScreen(); 
  orientation(LANDSCAPE);
  requestPermission("android.permission.WRITE_EXTERNAL_STORAGE", "handleRequest");
  
  frameRate(5);  
  textAlign(CENTER, CENTER);
  textSize(displayDensity * 25);
  
  sensor = new KetaiSensor(this);
  sensor.start();
}

void draw() {
  background(78, 93, 75);
  if (isCapturing)
  {
    text("Recording Accellerometer Data...\n(touch screen to stop)", width/2, height/4);
  }
  else
  {
    plotData();
    text("Visualizing last " + width + " point(s) of data.", width/2, height/4);
  }
  
  if (db != null)
  {
    text("Current Data count: " + db.getDataCount(), width/2, height-height/4);
  } else 
  {
    text("Cannot save data", width/2, height-height/4);
  }
}

void mousePressed()
{
  if (isCapturing)
    isCapturing = false;
  else
    isCapturing = true;
}

//      collect accelerometer data and save it to the database
void onAccelerometerEvent(float x, float y, float z, long time, int accuracy)
{
  if (db != null && db.connect() && isCapturing)
  {
    if (!db.execute("INSERT into data ('time','x','y','z') VALUES ('"+System.currentTimeMillis()+"', '" + x + "', '" + y + "', '" + z + "')")){
      println("Failed to record data!");
    }
    S.add(productoEscalar(x, y, z));
    buscarMaxmiosMinimos();
  }
}

void plotData()
{
  if (db != null && db.connect())
  {
    pushStyle();
    noStroke();
    db.query("SELECT * FROM data ORDER BY time DESC LIMIT " + width);
    int  i = 0;   
    long mymin = Long.parseLong(db.getFieldMin("data", "time"));
    long mymax = Long.parseLong(db.getFieldMax("data", "time"));
    while (db.next())
    {

      float x = db.getFloat("x");
      float y = db.getFloat("y");
      float z = db.getFloat("z");
      long  t = db.getLong("time");
      int plotx = (int)maplong(t, mymin, mymax, 0, width);

      fill(255, 0, 0);
      ellipse(plotx, map(x, -30, 30, 0, height), 5, 5);
      fill(0, 255, 0);
      ellipse(i, map(y, -30, 30, 0, height), 5, 5);
      fill(0, 0, 255);
      ellipse(i, map(z, -30, 30, 0, height), 5, 5);

      i++;
    }
    
    popStyle();
  }
}

public boolean saberSiMaximo(double x, double y, boolean continua)
{
  return x < y && continua;
}


public boolean saberSiMinimo(double x, double y, boolean continua)
{
  return x > y && continua;
}

public int contarPuntos()
{
  int n = 0;
  db.query("SELECT COUNT(i) FROM data");
  if(db.next())
  {
    n = db.getInt(1);
  }
  return n;
}

public void cargarPuntos()
{
  db.query("SELECT * FROM data");
  while (db.next())
  {
    S.add(productoEscalar(db.getFloat("x"), db.getFloat("y"), db.getFloat("z")));
    buscarMaxmiosMinimos();
  }
}

long maplong(long value, long istart, long istop, long ostart, long ostop) {
  long divisor = istop - istart;
  return (ostart + (ostop - ostart) * (value - istart) / divisor);
}

void handleRequest(boolean granted) {
  if (granted)
  {    
    db = new KetaiSQLite(this);
    if (db.connect())
    {
      if (!db.tableExists("data")){
        db.execute(CREATE_DB_SQL);
      }
    }
    cargarPuntos();
  }
}

public void buscarMaxmiosMinimos()
{
  boolean maximo;
  boolean minimo;
  if(S.size() > 2 * K  + 1)
  {
    maximo = true;
    minimo = true;
    for(int i = indice - K; i < indice; ++i)
    {
      maximo = saberSiMaximo(S.get(i), S.get(indice), maximo);
      minimo = saberSiMinimo(S.get(i), S.get(indice), minimo);
    }
    for(int i = indice + 1; i < K + indice; ++i)
    {
      maximo = saberSiMaximo(S.get(i), S.get(indice), maximo);
      minimo = saberSiMinimo(S.get(i), S.get(indice), minimo);
    }
    if(maximo)
    {
      candidatos.add(1);
    }
    else if(minimo)
    {
      candidatos.add(-1);
    }
    else
    {
      candidatos.add(0);
    }
    ++indice;
  }
}

public double productoEscalar(float x, float y, float z)
{
  return Math.sqrt((x * x) + (y * y) + (z * z));
}
