WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pv.UserId) AS UniqueVoters,
        SUM(v.BountyAmount) AS TotalBounty
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Votes pv ON p.Id = pv.PostId AND pv.VoteTypeId = 2  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CommentCount,
        ps.UniqueVoters,
        ps.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC) AS Rank
    FROM
        PostStats ps
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalVotes,
    ups.Upvotes,
    ups.Downvotes,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.CommentCount,
    tp.UniqueVoters,
    tp.TotalBounty
FROM
    UserVoteStats ups
JOIN
    TopPosts tp ON ups.TotalVotes > 10
WHERE
    tp.Rank <= 10
ORDER BY
    ups.TotalVotes DESC, tp.Score DESC;