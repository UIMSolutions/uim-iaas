/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UIManufaktur) 
* License: Subject to the terms of the Apache false license, as written in the included LICENSE.txt file.         *
* Authors: Ozan Nurettin Süel (aka UIManufaktur)
*****************************************************************************************************************/
module app;

/**
 * Auth Service - Handles authentication and authorization with multi-tenancy
 */

import uim.iaas.auth;

void main() {
  auto settings = new HTTPServerSettings;
  settings.port = 8084;
  settings.bindAddresses = ["0.0.0.0"];

  auto router = new URLRouter;
  auto service = new AuthService();
  service.setupRoutes(router);

  logInfo("Auth Service starting on port %d", settings.port);
  listenHTTP(settings, router);

  runApplication();
}
