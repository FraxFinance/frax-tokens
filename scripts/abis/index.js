"use strict";
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
Object.defineProperty(exports, "__esModule", { value: true });
exports.HOP_V2_ABI =
  exports.SEND_ULN302_ABI =
  exports.REMOTE_MINT_REDEEM_HOP_ABI =
  exports.REMOTE_HOP_ABI =
  exports.RECEIVE_ULN302_ABI =
  exports.FRAXTAL_MINT_REDEEM_HOP_ABI =
  exports.FRAXTAL_HOP_ABI =
  exports.FRAX_PROXY_ADMIN_ABI =
  exports.ENDPOINTV2_ABI =
  exports.OFT_MINTABLE_ADAPTER_ABI =
  exports.OFT_ADAPTER_ABI =
  exports.OFT_ABI =
  exports.ERC20ABI =
    void 0;
const OFT_ABI_json_1 = __importDefault(require("./OFT_ABI.json"));
exports.OFT_ABI = OFT_ABI_json_1.default;
const OFT_ADAPTER_ABI_json_1 = __importDefault(require("./OFT_ADAPTER_ABI.json"));
exports.OFT_ADAPTER_ABI = OFT_ADAPTER_ABI_json_1.default;
const OFT_MINTABLE_ADAPTER_ABI_json_1 = __importDefault(require("./OFT_MINTABLE_ADAPTER_ABI.json"));
exports.OFT_MINTABLE_ADAPTER_ABI = OFT_MINTABLE_ADAPTER_ABI_json_1.default;
const ENDPOINTV2_ABI_json_1 = __importDefault(require("./ENDPOINTV2_ABI.json"));
exports.ENDPOINTV2_ABI = ENDPOINTV2_ABI_json_1.default;
const FRAX_PROXY_ADMIN_ABI_json_1 = __importDefault(require("./FRAX_PROXY_ADMIN_ABI.json"));
exports.FRAX_PROXY_ADMIN_ABI = FRAX_PROXY_ADMIN_ABI_json_1.default;
const FRAXTAL_HOP_json_1 = __importDefault(require("./FRAXTAL_HOP.json"));
exports.FRAXTAL_HOP_ABI = FRAXTAL_HOP_json_1.default;
const FRAXTAL_MINT_REDEEM_HOP_json_1 = __importDefault(require("./FRAXTAL_MINT_REDEEM_HOP.json"));
exports.FRAXTAL_MINT_REDEEM_HOP_ABI = FRAXTAL_MINT_REDEEM_HOP_json_1.default;
const RECEIVE_ULN302_ABI_json_1 = __importDefault(require("./RECEIVE_ULN302_ABI.json"));
exports.RECEIVE_ULN302_ABI = RECEIVE_ULN302_ABI_json_1.default;
const REMOTE_HOP_ABI_json_1 = __importDefault(require("./REMOTE_HOP_ABI.json"));
exports.REMOTE_HOP_ABI = REMOTE_HOP_ABI_json_1.default;
const REMOTE_MINT_REDEEM_HOP_json_1 = __importDefault(require("./REMOTE_MINT_REDEEM_HOP.json"));
exports.REMOTE_MINT_REDEEM_HOP_ABI = REMOTE_MINT_REDEEM_HOP_json_1.default;
const SEND_ULN302_ABI_json_1 = __importDefault(require("./SEND_ULN302_ABI.json"));
exports.SEND_ULN302_ABI = SEND_ULN302_ABI_json_1.default;
const HOP_V2_ABI_json_1 = __importDefault(require("./HOP_V2_ABI.json"));
exports.HOP_V2_ABI = HOP_V2_ABI_json_1.default;
var ERC20_1 = require("./ERC20");
Object.defineProperty(exports, "ERC20ABI", {
  enumerable: true,
  get: function () {
    return ERC20_1.ERC20ABI;
  },
});
