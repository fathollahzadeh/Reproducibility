WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS YearlyRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '5 years'
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE YearlyRank <= 5
),
CommentStats AS (
    SELECT
        PostId,
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM
        Comments
    GROUP BY
        PostId
),
PostVotes AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM
        Votes
    GROUP BY
        PostId
)
SELECT
    tp.Id,
    tp.Title,
    tp.CreationDate,
    COALESCE(cs.TotalComments, 0) AS TotalComments,
    COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN COALESCE(v.Upvotes, 0) + COALESCE(v.Downvotes, 0) > 0 THEN 
            (COALESCE(v.Upvotes, 0) * 1.0 / (COALESCE(v.Upvotes, 0) + COALESCE(v.Downvotes, 0)) * 100)
        ELSE 
            NULL
    END AS ApprovalRating
FROM
    TopPosts tp
LEFT JOIN
    CommentStats cs ON tp.Id = cs.PostId
LEFT JOIN
    PostVotes v ON tp.Id = v.PostId
ORDER BY
    tp.CreationDate DESC;