
WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        EXTRACT(EPOCH FROM COALESCE(p.ClosedDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate) / 60 AS MinutesActive,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.AcceptedAnswerId
),
AggregatedStats AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVoteCount) - SUM(DownVoteCount) AS NetVotes,
        AVG(MinutesActive) AS AvgActiveMinutes
    FROM 
        RecursivePostStats
    WHERE 
        PostRank <= 10 
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        a.TotalPosts,
        a.QuestionsCount,
        a.AnswersCount,
        a.TotalComments,
        a.NetVotes,
        CASE 
            WHEN a.NetVotes IS NULL THEN 'Not Voted Yet' 
            WHEN a.NetVotes > 100 THEN 'Top Voter'
            WHEN a.NetVotes BETWEEN 1 AND 100 THEN 'Moderate Voter'
            ELSE 'Negative Voter'
        END AS UserVotingCategory
    FROM 
        Users u
    LEFT JOIN 
        AggregatedStats a ON u.Id = a.OwnerUserId
    WHERE 
        u.Reputation > 500 
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    COALESCE(tu.TotalPosts, 0) AS TotalPosts,
    COALESCE(tu.QuestionsCount, 0) AS QuestionsCount,
    COALESCE(tu.AnswersCount, 0) AS AnswersCount,
    COALESCE(tu.TotalComments, 0) AS TotalComments,
    COALESCE(tu.NetVotes, 0) AS NetVotes,
    tu.UserVotingCategory,
    CASE 
        WHEN tu.TotalPosts IS NULL THEN 'No Activity'
        WHEN tu.TotalPosts > 50 THEN 'Highly Active'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM 
    TopUsers tu
ORDER BY 
    tu.NetVotes DESC NULLS LAST, 
    tu.TotalPosts DESC, 
    tu.DisplayName;
