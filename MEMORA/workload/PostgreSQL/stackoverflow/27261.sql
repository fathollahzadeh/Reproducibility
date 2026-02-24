WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
TopScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),
FullDetails AS (
    SELECT 
        tsp.*,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        TopScoringPosts tsp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tsp.PostId)
    GROUP BY 
        tsp.PostId, tsp.Title, tsp.Body, tsp.CreationDate, tsp.Score, tsp.ViewCount, tsp.Tags, tsp.OwnerDisplayName, tsp.CommentCount, tsp.VoteCount
)
SELECT 
    fd.PostId,
    fd.Title,
    fd.Body,
    fd.CreationDate,
    fd.Score,
    fd.ViewCount,
    fd.Tags,
    fd.OwnerDisplayName,
    fd.CommentCount,
    fd.VoteCount,
    fd.BadgeNames,
    CASE 
        WHEN fd.Score >= 50 THEN 'Highly Rated'
        WHEN fd.Score >= 20 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    FullDetails fd
ORDER BY 
    fd.Score DESC, fd.ViewCount DESC;