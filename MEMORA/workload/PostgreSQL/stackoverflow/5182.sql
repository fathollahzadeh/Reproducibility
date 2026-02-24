
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName, 
    TotalScore, 
    TotalViews, 
    TotalComments,
    RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
FROM 
    TopUsers
ORDER BY 
    UserRank
LIMIT 10;
