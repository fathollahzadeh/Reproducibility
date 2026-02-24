WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
QuestionStats AS (
    SELECT 
        q.Id,
        q.Title,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(avg(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - q.CreationDate)) / 3600), 0) AS HoursSinceCreation
    FROM 
        TopQuestions q
    LEFT JOIN 
        Comments c ON c.PostId = q.Id
    LEFT JOIN 
        Votes v ON v.PostId = q.Id
    GROUP BY 
        q.Id, q.Title
)
SELECT 
    qs.Title,
    qs.TotalCommentScore,
    qs.CommentCount,
    qs.UpVotes,
    qs.DownVotes,
    CASE 
        WHEN qs.HoursSinceCreation < 24 THEN 'Recent'
        WHEN qs.HoursSinceCreation >= 24 AND qs.HoursSinceCreation < 720 THEN 'Moderate'
        ELSE 'Old' 
    END AS PostAgeCategory
FROM 
    QuestionStats qs
WHERE 
    qs.TotalCommentScore > 0
ORDER BY 
    qs.UpVotes DESC, qs.CommentCount DESC
LIMIT 5;