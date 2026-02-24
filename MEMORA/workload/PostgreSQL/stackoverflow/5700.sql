
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        Users.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        COUNT(Comments.Id) AS CommentCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users ON P.OwnerUserId = Users.Id
    LEFT JOIN 
        Comments ON P.Id = Comments.PostId
    LEFT JOIN 
        Votes ON P.Id = Votes.PostId
    WHERE 
        P.CreationDate >= current_timestamp - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, Users.DisplayName, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)

SELECT 
    T.PostId,
    T.Title,
    T.OwnerDisplayName,
    T.CreationDate,
    T.Score,
    T.CommentCount,
    T.UpVoteCount,
    T.DownVoteCount,
    COALESCE((SELECT STRING_AGG(Tag.TagName, ', ') 
               FROM Tags Tag 
               WHERE Tag.ExcerptPostId = T.PostId), 'No Tags') AS Tags
FROM 
    TopPosts T
ORDER BY 
    T.Score DESC, 
    T.CreationDate ASC;
