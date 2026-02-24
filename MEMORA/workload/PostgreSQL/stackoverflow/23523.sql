
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.PostTypeId, p.Score
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.GoldBadges, 0) AS GoldBadgeCount,
        COALESCE(b.SilverBadges, 0) AS SilverBadgeCount,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadgeCount,
        pu.PostCount
    FROM 
        Users u
    LEFT JOIN 
        (SELECT OwnerUserId AS UserId, COUNT(*) AS PostCount FROM Posts GROUP BY OwnerUserId) pu ON u.Id = pu.UserId
    LEFT JOIN 
        BadgeSummary b ON u.Id = b.UserId
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.RankScore,
    r.CommentCount,
    r.NetVotes,
    p.FirstChangeDate,
    p.LastChangeDate,
    p.CloseReopenCount,
    u.DisplayName,
    u.GoldBadgeCount,
    u.SilverBadgeCount,
    u.BronzeBadgeCount
FROM 
    RankedPosts r
JOIN 
    PostHistoryDetails p ON r.PostId = p.PostId
LEFT JOIN 
    UserActivity u ON u.UserId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
WHERE 
    r.RankScore = 1
    AND r.NetVotes >= 10
    AND (p.CloseReopenCount <= 2 OR p.CloseReopenCount IS NULL)
ORDER BY 
    r.ViewCount DESC, 
    u.GoldBadgeCount DESC
FETCH FIRST 10 ROWS ONLY;
