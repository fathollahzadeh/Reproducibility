
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COALESCE(MAX(ph.CreationDate), '1900-01-01') AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY p.Id, p.Title
),
FilteredPosts AS (
    SELECT 
        rpa.PostId,
        rpa.Title,
        rpa.CommentCount,
        rpa.TotalUpvotes,
        rpa.TotalDownvotes,
        (rpa.TotalUpvotes - rpa.TotalDownvotes) AS NetScore,
        rpa.LastEditDate
    FROM RecentPostActivity rpa
    WHERE rpa.CommentCount > 5 AND (rpa.TotalUpvotes - rpa.TotalDownvotes) > 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
FinalResult AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CommentCount,
        fp.NetScore,
        fp.LastEditDate,
        ur.DisplayName AS TopReputationUser,
        ur.TotalBadges
    FROM FilteredPosts fp
    LEFT JOIN UserReputation ur ON fp.PostId = (
        SELECT p.Id
        FROM Posts p
        WHERE p.OwnerUserId IS NOT NULL
        ORDER BY p.Score DESC, p.ViewCount DESC
        LIMIT 1
    )
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CommentCount,
    fr.NetScore,
    fr.LastEditDate,
    COALESCE(fr.TopReputationUser, 'No Users') AS TopReputationUser,
    COALESCE(fr.TotalBadges, 0) AS TotalBadges
FROM FinalResult fr
ORDER BY fr.NetScore DESC, fr.CommentCount DESC;
