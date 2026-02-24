
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
), 
ClosedPostCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
), 
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    psc.CloseCount,
    psc.ReopenCount,
    ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC) AS PopularityRank,
    COALESCE(up.BadgeNames, 'No Badges') AS TopUserBadges
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPostCounts psc ON ps.Id = psc.PostId
LEFT JOIN 
    TopUsers tu ON tu.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = ps.Id)
LEFT JOIN 
    UserBadges up ON tu.Id = up.UserId
WHERE 
    ps.UpVotes - ps.DownVotes > 10 
    OR (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.Id) > 5
ORDER BY 
    ps.ViewCount DESC
LIMIT 20;
