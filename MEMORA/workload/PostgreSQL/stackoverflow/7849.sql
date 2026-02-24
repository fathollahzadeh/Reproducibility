WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Coalesce(c.CommentCount, 0)) AS TotalComments,
        SUM(Coalesce(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(Coalesce(v.DownVotes, 0)) AS TotalDownVotes
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM
            Votes
        GROUP BY
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM
        UserActivity
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    PostRank,
    UpVoteRank
FROM
    TopUsers
WHERE
    PostRank <= 10 OR UpVoteRank <= 10
ORDER BY
    PostRank, UpVoteRank;
