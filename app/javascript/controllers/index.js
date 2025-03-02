// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// app/javascript/controllers/index.js
// Remove the redundant import statement
// import { application } from "./application"

import LocationController from "./location_controller"
application.register("location", LocationController)
