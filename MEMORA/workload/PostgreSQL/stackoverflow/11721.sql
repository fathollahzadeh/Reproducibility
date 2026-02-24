
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        p.CommentCount, p.FavoriteCount, p.AcceptedAnswerId, p.OwnerUserId, 
        u.Reputation
),
VoteStats AS (
    SELECT
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Votes
    GROUP BY
        PostId
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.AcceptedAnswerId,
    ps.OwnerUserId,
    ps.OwnerReputation,
    ps.Tags,
    COALESCE(vs.VoteCount, 0) AS TotalVotes,
    COALESCE(vs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vs.Downvotes, 0) AS TotalDownvotes
FROM
    PostStats ps
LEFT JOIN
    VoteStats vs ON ps.PostId = vs.PostId
ORDER BY
    ps.CreationDate DESC
LIMIT 100;
