
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        RecentUserPosts
    WHERE 
        PostCount > 0
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.TotalScore,
    (SELECT 
        COUNT(*)
     FROM 
        Votes v
     WHERE 
        v.UserId = up.UserId AND v.VoteTypeId = 2) AS UpvoteCount,
    COUNT(DISTINCT p.Id) FILTER (WHERE p.Score > 0) AS PositivePosts,
    p.CreationDate,
    ph.HistoryCount,
    ph.HistoryTypes
FROM 
    TopUsers up
LEFT JOIN 
    Posts p ON up.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistories ph ON p.Id = ph.PostId
WHERE 
    up.UserRank <= 10 
GROUP BY 
    up.UserId, up.DisplayName, up.PostCount, up.TotalViews, up.TotalScore, p.CreationDate, ph.HistoryCount, ph.HistoryTypes
ORDER BY 
    up.TotalScore DESC, up.PostCount DESC;
