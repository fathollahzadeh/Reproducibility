
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01'
),
PostDetail AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.Score,
        r.Rank,
        r.UpVoteCount,
        r.DownVoteCount,
        CASE 
            WHEN r.UpVoteCount > r.DownVoteCount THEN 'Popular'
            WHEN r.UpVoteCount < r.DownVoteCount THEN 'Controversial'
            ELSE 'Neutral'
        END AS PostType,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT DISTINCT CAST(UNNEST(string_to_array(p.Tags, '>')) AS INTEGER) 
                        FROM Posts p 
                        WHERE p.Id = r.PostId)
                       AND p.PostTypeId = 1) AS TagsList
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON r.PostId = p.Id
    WHERE 
        r.Rank <= 10
),
CommentData AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Score,
        pd.PostType,
        COALESCE(cd.CommentCount, 0) AS CommentCount,
        COALESCE(cd.Comments, 'No comments') AS Comments,
        CASE 
            WHEN pd.Score > 100 THEN 'High Score'
            WHEN pd.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostDetail pd
    LEFT JOIN 
        CommentData cd ON pd.PostId = cd.PostId
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    PostType,
    CommentCount,
    Comments,
    ScoreCategory,
    CloseCount,
    (CASE 
         WHEN CloseCount > 0 THEN 'Closed Posts'
         ELSE 'Open Posts'
     END) AS PostStatus
FROM 
    FinalResults
WHERE 
    CloseCount < 3
ORDER BY 
    ViewCount DESC, PostId ASC;
