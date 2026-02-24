WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
RankedQuestions AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount,
        RANK() OVER (ORDER BY Score DESC, CreationDate ASC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    rq.Title,
    rq.Score,
    rq.CreationDate,
    rq.OwnerDisplayName,
    rq.CommentCount,
    rq.UpvoteCount,
    CASE 
        WHEN rq.Rank <= 10 THEN 'Top 10 Questions'
        WHEN rq.Rank <= 50 THEN 'Top 50 Questions'
        ELSE 'Other Questions'
    END AS RankCategory
FROM 
    RankedQuestions rq
WHERE 
    rq.Rank <= 100
ORDER BY 
    rq.Rank;