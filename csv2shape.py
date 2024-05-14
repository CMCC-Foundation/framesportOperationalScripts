#!/usr/bin/python

import sys, getopt, os, shutil
import csv
import osgeo.ogr, osgeo.osr
from osgeo import ogr
import traceback

import logging

driver = osgeo.ogr.GetDriverByName('ESRI Shapefile')
spatialReference = osgeo.osr.SpatialReference()
spatialReference.ImportFromEPSG(4326)
# outputdir = "/var/www/html/cache/_VISIR-GUTTA/OUTPUT"
path = os.path.dirname(sys.argv[0])
param = ""


def write_shapefile(inputfile):

    try:
        outputfileShp = os.path.join(os.path.dirname(inputfile),os.path.splitext(os.path.basename(inputfile))[0] + '.shp')
        print("outputfileShp-->",outputfileShp)
        shapeFile = driver.CreateDataSource(outputfileShp)

        var_name = os.path.splitext(os.path.basename(inputfile))[0]
        print("var_name-->",var_name)

        layerLname = os.path.splitext(os.path.basename(inputfile))[0] + '.crv'
        print("layerLname-->",layerLname)

        layerL = shapeFile.CreateLayer(layerLname, spatialReference, osgeo.ogr.wkbLineString)
        layerL_defn = layerL.GetLayerDefn()
        # print("inputfile-->",inputfile)

        with open(inputfile, 'r') as csvfile:
            print("---------------------------")
            reader = csv.DictReader(csvfile, delimiter=',', skipinitialspace=True)
            #  for each column
            for field in reader.fieldnames:
		#  print("FIELD-->",field)
                if field=='lon': datatype = ogr.OFTReal
                elif field=='lat': datatype = ogr.OFTReal
                elif field=='dist': datatype = ogr.OFTInteger
                elif field=='time': datatype = ogr.OFTInteger
                elif field=='CO2t': datatype = ogr.OFTInteger
                elif field=='plotIdx': datatype = ogr.OFTInteger
                else: datatype = ogr.OFTString

                new_field = ogr.FieldDefn(field, datatype)
                layerL.CreateField(new_field)

            featureL = osgeo.ogr.Feature(layerL_defn)

            #  for each row (ADD POINTS to featureP layer)
            idx = -1
            for row in reader:
                tmpidx = row['plotIdx']
                if tmpidx != idx:
                    # print("NEW line -->",row)
                    isoline = ogr.Geometry(ogr.wkbLineString)
                # else:
                    # print("   SAME line -->",row)
                isoline.AddPoint_2D( float(row['lon']), float(row['lat']) )
                idx = row['plotIdx']
                featureL.SetGeometryDirectly(isoline)
                featureL.SetField("lat", row['lat'])
                featureL.SetField("lon", row['lon'])
                featureL.SetField(var_name, row[var_name])
                featureL.SetField("plotIdx", row['plotIdx'])
                layerL.CreateFeature(featureL)
            featureL = None

        shapeFile.Destroy()
    except:
        sys.exit(1)


def main(argv):


    inputfile = ''
    err_str = '\n\nERROR: missing input parameter. \nUsage: csv2shape.py -i <filename.csv>'

    try:
        opts, args = getopt.getopt(argv,'hi:',['help','ifile='])
    except getopt.GetoptError:
        # print('except:',err_str)
        sys.exit(1)

    if len(opts)<1:
        print ("opts: ", opts)
        # print(err_str,opts)
        sys.exit(1)

    for opt, arg in opts:
        if opt == '-h':
            # print('\nUsage: csv2shape.py -i <filename.csv>')
            sys.exit()
        elif opt in ("-i", "--input"):
            inputfile = arg
        else:
            # print(err_str)
            sys.exit(1)

    # if not os.path.exists(outputdir):
    #     os.makedirs(outputdir)

    # print("________________________________________________")
    # print("Creating shapefiles..........")
    print('Input file is: ', inputfile)
    write_shapefile(inputfile)
    print("...........done")

    sys.exit(0)




if __name__ == "__main__":
    main(sys.argv[1:])
    







