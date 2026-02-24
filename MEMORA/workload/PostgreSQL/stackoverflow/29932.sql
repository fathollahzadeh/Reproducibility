
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1  
    GROUP BY Tag
),
TopTags AS (
    SELECT Tag
    FROM TagCounts
    ORDER BY PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  
    AND EXISTS (SELECT 1 FROM TagCounts tc WHERE tc.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    GROUP BY p.Id, u.DisplayName
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.OwnerName,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        COALESCE(pd.UpVotes::float / NULLIF(pd.DownVotes, 0), 0) AS UpvoteDownvoteRatio
    FROM PostDetails pd
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.OwnerName,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.UpvoteDownvoteRatio
FROM FinalResults fr
WHERE fr.OwnerName IS NOT NULL
ORDER BY fr.UpvoteDownvoteRatio DESC, fr.ViewCount DESC
LIMIT 20;
