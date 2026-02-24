WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName
),
FilteredRankedPosts AS (
    SELECT 
        *,
        CASE 
            WHEN AnswerCount > 0 THEN 'Has Answers' 
            ELSE 'No Answers' 
        END AS AnswerStatus
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 10
),
PostInteractions AS (
    SELECT 
        f.PostId,
        f.Title,
        f.OwnerDisplayName,
        f.AnswerStatus,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        FilteredRankedPosts f
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
             Votes
         GROUP BY 
             PostId) v ON f.PostId = v.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.AnswerStatus,
    p.UpVotes,
    p.DownVotes,
    COALESCE(c.CommentCount, 0) AS TotalComments
FROM 
    PostInteractions p
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON p.PostId = c.PostId
ORDER BY 
    p.UpVotes DESC, 
    p.DownVotes ASC;