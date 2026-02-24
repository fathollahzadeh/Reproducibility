
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteScore 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        hp.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes hp ON ph.PostHistoryTypeId = hp.Id
    WHERE 
        hp.Name LIKE 'Post Closed%'
)
SELECT 
    rp.PostId,
    rp.Title,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.VoteScore,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(cp.CreationDate::TEXT, 'N/A') AS CloseDate,
    rp.CommentCount,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest'
        WHEN rp.UserPostRank <= 5 THEN 'Top 5'
        ELSE 'Older Posts'
    END AS PostRankCategory
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPostDetails cp ON cp.PostId = rp.PostId
WHERE 
    us.Reputation > 100 
ORDER BY 
    us.Reputation DESC, rp.CommentCount DESC
FETCH FIRST 50 ROWS ONLY;
