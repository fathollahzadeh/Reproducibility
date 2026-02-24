
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPostTypes AS (
    SELECT 
        pt.Name AS PostTypeName,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
    GROUP BY 
        pt.Id, pt.Name
)
SELECT 
    tpt.PostTypeName,
    tpt.AvgScore,
    tpt.TotalViews,
    tpt.TotalComments,
    (SELECT COUNT(*) FROM Posts p WHERE p.PostTypeId IN 
        (SELECT Id FROM PostTypes WHERE Name = tpt.PostTypeName)) AS PostCount
FROM 
    TopPostTypes tpt
ORDER BY 
    tpt.AvgScore DESC, tpt.TotalViews DESC;
