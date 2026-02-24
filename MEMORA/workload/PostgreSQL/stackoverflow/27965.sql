
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
PopularUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(Score) AS TotalScore,
        COUNT(PostId) AS TotalPosts
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(PostId) >= 3  
),
BadgeSummary AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    pu.OwnerDisplayName,
    pu.TotalScore,
    pu.TotalPosts,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.BadgeNames, '') AS BadgeNames
FROM 
    PopularUsers pu
LEFT JOIN 
    BadgeSummary bs ON pu.OwnerDisplayName = bs.DisplayName
ORDER BY 
    pu.TotalScore DESC,
    pu.TotalPosts DESC;
