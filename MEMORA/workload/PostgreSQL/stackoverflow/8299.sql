WITH RankedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.ViewCount,
        COUNT(Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY Posts.CreationDate DESC) AS Rank
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId 
    WHERE 
        Posts.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.CreationDate, Posts.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        CommentCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.Title,
    T.CreationDate,
    T.ViewCount,
    T.CommentCount,
    T.Upvotes,
    T.Downvotes
FROM 
    TopPosts T
JOIN 
    Users U ON T.PostId = U.Id
ORDER BY 
    T.Upvotes DESC, T.ViewCount DESC;