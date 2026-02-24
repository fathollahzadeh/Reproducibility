
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank <= 5
)
SELECT 
    trp.OwnerDisplayName,
    COUNT(trp.PostId) AS TotalPosts,
    SUM(trp.Score) AS TotalScore,
    AVG(trp.ViewCount) AS AverageViewCount,
    SUM(trp.CommentCount) AS TotalComments,
    MAX(trp.CreationDate) AS LatestPostDate
FROM 
    TopRankedPosts trp
GROUP BY 
    trp.OwnerDisplayName
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 10;
