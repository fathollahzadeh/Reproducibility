SELECT
    COUNT(*)
FROM
    comments as c,
    postHistory as ph,
    badges as b,
    users as u
WHERE
    u.Id = b.UserId
    AND u.Id = ph.UserId
    AND u.Id = c.UserId
    AND ph.PostHistoryTypeId = 2
    AND ph.CreationDate <= '2014-08-01 13:56:22'
    AND b.Date <= '2014-09-02 23:33:16'
    AND u.Views >= 0
    AND u.DownVotes >= 0
    AND u.UpVotes >= 0
    AND u.UpVotes <= 62
    AND u.CreationDate >= '2010-07-27 17:10:30'
    AND u.CreationDate <= '2014-07-31 18:48:36';