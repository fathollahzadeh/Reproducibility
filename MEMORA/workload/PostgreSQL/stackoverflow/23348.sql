WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
    GROUP BY 
        c.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopened,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    COALESCE(rc.LastCommentDate, NULL) AS LastCommentDate,
    COALESCE(pHS.LastClosed, NULL) AS LastClosed,
    COALESCE(pHS.LastReopened, NULL) AS LastReopened,
    ut.DisplayName AS TopUser,
    ut.TotalBounty,
    ut.UserRank,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 10 THEN 'Highly Scored'
        ELSE 'Moderately Scored'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistorySummary pHS ON rp.PostId = pHS.PostId
LEFT JOIN 
    TopUsers ut ON rp.PostId IN (
        SELECT PostId
        FROM Votes
        WHERE BountyAmount > 0 
        AND VoteTypeId = 9
    )
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC NULLS LAST,
    rp.Score DESC;