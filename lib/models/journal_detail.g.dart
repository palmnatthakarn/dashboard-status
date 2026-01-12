// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JournalDetail _$JournalDetailFromJson(Map<String, dynamic> json) =>
    JournalDetail(
      guidfixed: json['guidfixed'] as String?,
      batchid: json['batchid'] as String?,
      docno: json['docno'] as String?,
      docdate: json['docdate'] as String?,
      documentref: json['documentref'] as String?,
      accountperiod: (json['accountperiod'] as num?)?.toInt(),
      accountyear: (json['accountyear'] as num?)?.toInt(),
      accountgroup: json['accountgroup'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      accountdescription: json['accountdescription'] as String?,
      bookcode: json['bookcode'] as String?,
      vats: json['vats'] as List<dynamic>?,
      taxes: json['taxes'] as List<dynamic>?,
      journaltype: (json['journaltype'] as num?)?.toInt(),
      exdocrefno: json['exdocrefno'] as String?,
      exdocrefdate: json['exdocrefdate'] as String?,
      docformat: json['docformat'] as String?,
      appname: json['appname'] as String?,
      debtaccounttype: (json['debtaccounttype'] as num?)?.toInt(),
      creditor: json['creditor'] == null
          ? null
          : JournalPerson.fromJson(json['creditor'] as Map<String, dynamic>),
      debtor: json['debtor'] == null
          ? null
          : JournalPerson.fromJson(json['debtor'] as Map<String, dynamic>),
      jobguidfixed: json['jobguidfixed'] as String?,
      journaldetail: (json['journaldetail'] as List<dynamic>?)
          ?.map((e) => JournalDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdby: json['createdby'] as String?,
      createdat: json['createdat'] as String?,
    );

Map<String, dynamic> _$JournalDetailToJson(JournalDetail instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'batchid': instance.batchid,
      'docno': instance.docno,
      'docdate': instance.docdate,
      'documentref': instance.documentref,
      'accountperiod': instance.accountperiod,
      'accountyear': instance.accountyear,
      'accountgroup': instance.accountgroup,
      'amount': instance.amount,
      'accountdescription': instance.accountdescription,
      'bookcode': instance.bookcode,
      'vats': instance.vats,
      'taxes': instance.taxes,
      'journaltype': instance.journaltype,
      'exdocrefno': instance.exdocrefno,
      'exdocrefdate': instance.exdocrefdate,
      'docformat': instance.docformat,
      'appname': instance.appname,
      'debtaccounttype': instance.debtaccounttype,
      'creditor': instance.creditor,
      'debtor': instance.debtor,
      'jobguidfixed': instance.jobguidfixed,
      'journaldetail': instance.journaldetail,
      'createdby': instance.createdby,
      'createdat': instance.createdat,
    };

JournalPerson _$JournalPersonFromJson(Map<String, dynamic> json) =>
    JournalPerson(
      guidfixed: json['guidfixed'] as String?,
      code: json['code'] as String?,
      personaltype: (json['personaltype'] as num?)?.toInt(),
      customertype: (json['customertype'] as num?)?.toInt(),
      branchnumber: json['branchnumber'] as String?,
      taxid: json['taxid'] as String?,
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => PersonName.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JournalPersonToJson(JournalPerson instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'personaltype': instance.personaltype,
      'customertype': instance.customertype,
      'branchnumber': instance.branchnumber,
      'taxid': instance.taxid,
      'names': instance.names,
    };

PersonName _$PersonNameFromJson(Map<String, dynamic> json) => PersonName(
  code: json['code'] as String?,
  name: json['name'] as String?,
  isauto: json['isauto'] as bool?,
  isdelete: json['isdelete'] as bool?,
);

Map<String, dynamic> _$PersonNameToJson(PersonName instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'isauto': instance.isauto,
      'isdelete': instance.isdelete,
    };

JournalDetailItem _$JournalDetailItemFromJson(Map<String, dynamic> json) =>
    JournalDetailItem(
      accountcode: json['accountcode'] as String?,
      accountname: json['accountname'] as String?,
      debitamount: (json['debitamount'] as num?)?.toDouble(),
      creditamount: (json['creditamount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$JournalDetailItemToJson(JournalDetailItem instance) =>
    <String, dynamic>{
      'accountcode': instance.accountcode,
      'accountname': instance.accountname,
      'debitamount': instance.debitamount,
      'creditamount': instance.creditamount,
    };
