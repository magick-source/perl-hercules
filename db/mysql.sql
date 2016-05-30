CREATE TABLE `cronjob` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `cron_group` varchar(64) NOT NULL DEFAULT '',
  `class` varchar(128) NOT NULL,
  `params` text,
  `run_every` varchar(5) NOT NULL DEFAULT '',
  `run_after` varchar(64) NOT NULL DEFAULT '',
  `run_schedule` varchar(30) DEFAULT '',
  `last_run_ok_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `error_cnt` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `running_until_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `running_server` varchar(128) NOT NULL DEFAULT '',
  `next_run_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `max_run_time` int(10) unsigned NOT NULL DEFAULT '0',
  `flags` set('active','unscheduled','failing') DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `next_run_epoch` (`next_run_epoch`,`running_until_epoch`,`cron_group`,`flags`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE `cronjob_group` (
  `group_name` varchar(64) NOT NULL DEFAULT '',
  `max_parallel_jobs` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `server_name` varchar(128) NOT NULL DEFAULT '',
  `elected_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `last_run_start_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `next_run_start_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  `re_elect_epoch` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`group_name`),
  KEY `server_name` (`server_name`),
  KEY `re_elect_epoch` (`re_elect_epoch`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cronjob_output` (
  `cronjob_id` int(10) unsigned NOT NULL DEFAULT '0',
  `server_name` varchar(128) NOT NULL DEFAULT '',
  `run_epoch` int(10) unsigned DEFAULT '0',
  `exit_code` int(11) NOT NULL DEFAULT '-1',
  `output` mediumtext,
  PRIMARY KEY (`cronjob_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


