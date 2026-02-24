WITH UserVoteSummary AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id,
        u.DisplayName
),
PostInteractionSummary AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) AS EditorsCount
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id,
        p.Title
),
CombinedSummary AS (
    SELECT
        uvs.UserId,
        uvs.DisplayName,
        uvs.TotalVotes,
        uvs.UpVotesCount,
        uvs.DownVotesCount,
        pis.PostId,
        pis.Title AS PostTitle,
        pis.TotalUpVotes,
        pis.TotalDownVotes,
        pis.CommentCount,
        pis.EditorsCount
    FROM
        UserVoteSummary uvs
    JOIN
        PostInteractionSummary pis ON pis.TotalUpVotes > 5
)
SELECT
    UserId,
    DisplayName,
    TotalVotes,
    UpVotesCount,
    DownVotesCount,
    PostId,
    PostTitle,
    TotalUpVotes,
    TotalDownVotes,
    CommentCount,
    EditorsCount
FROM
    CombinedSummary
WHERE
    TotalVotes > 10
ORDER BY
    TotalVotes DESC, UpVotesCount DESC;
