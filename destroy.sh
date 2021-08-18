#!/bin/bash

export $(xargs < ppp.env)
az group delete -n $RESOURCE_GROUP