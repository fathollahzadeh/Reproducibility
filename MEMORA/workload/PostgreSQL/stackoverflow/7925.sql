
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopClosedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ClosedDate,
        us.DisplayName AS UserDisplayName,
        us.Reputation AS UserReputation
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.ClosedDate IS NOT NULL
)
SELECT 
    tcp.Title,
    tcp.CreationDate,
    tcp.Score,
    tcp.ViewCount,
    tcp.ClosedDate,
    tcp.UserDisplayName,
    tcp.UserReputation
FROM 
    TopClosedPosts tcp
ORDER BY 
    tcp.ClosedDate DESC 
FETCH FIRST 10 ROWS ONLY;
