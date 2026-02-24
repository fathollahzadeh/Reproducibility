
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostInformation AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedByOriginatorVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
), 
CombinedData AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.Body,
        pi.CreationDate,
        pi.CommentCount,
        pi.UpVotes,
        pi.DownVotes,
        pi.AcceptedByOriginatorVotes,
        ubc.UserId,
        ubc.DisplayName,
        ubc.BadgeCount,
        ubc.GoldCount,
        ubc.SilverCount,
        ubc.BronzeCount
    FROM 
        PostInformation pi
    JOIN 
        UserBadgeCounts ubc ON pi.OwnerUserId = ubc.UserId
)
SELECT 
    ubc.UserId,
    ubc.DisplayName,
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.CommentCount,
    cd.UpVotes,
    cd.DownVotes,
    cd.AcceptedByOriginatorVotes,
    ubc.BadgeCount,
    ubc.GoldCount,
    ubc.SilverCount,
    ubc.BronzeCount
FROM 
    CombinedData cd
JOIN 
    UserBadgeCounts ubc ON cd.UserId = ubc.UserId
WHERE 
    ubc.BadgeCount > 0
ORDER BY 
    ubc.BadgeCount DESC, cd.UpVotes DESC, cd.CommentCount DESC;
