
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.OwnerUserId
), UserTopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount,
        UserPostRank,
        DENSE_RANK() OVER (ORDER BY UpvoteCount DESC) AS UpvoteRank
    FROM 
        RankedPosts
)
SELECT 
    utp.OwnerDisplayName,
    utp.Title,
    utp.CommentCount,
    utp.AnswerCount,
    utp.UpvoteCount,
    utp.DownvoteCount
FROM 
    UserTopPosts utp
WHERE 
    utp.UserPostRank = 1 AND utp.UpvoteRank <= 10
ORDER BY 
    utp.UpvoteCount DESC, utp.CreationDate DESC;
