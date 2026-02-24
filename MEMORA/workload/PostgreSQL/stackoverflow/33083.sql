
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment AS EditComment,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Id IN (4, 5, 6) 
),
RecentChanges AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ChangesCount,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' (', ph.EditComment, ')'), '; ') AS ChangeDetails
    FROM 
        PostHistoryDetails ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerUserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.QuestionsCount,
    us.AnswersCount,
    us.AverageScore,
    rc.ChangesCount,
    rc.ChangeDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    RecentChanges rc ON rp.PostId = rc.PostId
WHERE 
    rp.UserPostRank <= 5 
ORDER BY 
    rp.CreationDate DESC;
