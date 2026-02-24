WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        tp.CommentCount,
        tp.Author,
        COALESCE(pc.TotalComments, 0) AS TotalComments,
        COALESCE(pb.TotalBadges, 0) AS TotalBadges
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
    LEFT JOIN 
        PostBadges pb ON pb.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = tp.Author LIMIT 1)
)
SELECT 
    *,
    (CASE 
        WHEN TotalComments > 100 THEN 'Highly Discussed'
        WHEN TotalComments BETWEEN 50 AND 100 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END) AS DiscussionLevel
FROM 
    FinalResults
ORDER BY 
    Score DESC, CreationDate DESC;