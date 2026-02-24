WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS VoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastModified,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS LastCloseReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ps.QuestionsAsked,
    ps.TotalScore AS UserTotalScore,
    phd.LastModified,
    phd.EditCount,
    phd.LastCloseReason,
    r.VoteScore AS PostVoteScore
FROM 
    RecursivePostCTE r
JOIN 
    Posts p ON r.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStatistics ps ON u.Id = ps.UserId
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId
WHERE 
    r.VoteScore > 0
    AND ps.QuestionsAsked > 5
ORDER BY 
    p.CreationDate DESC
LIMIT 100;