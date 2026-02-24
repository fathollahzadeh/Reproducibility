
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVotesRank,
        RANK() OVER (ORDER BY TotalDownVotes DESC) AS DownVotesRank
    FROM 
        UserActivity
),
UserHighlights AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        CommentCount,
        CASE 
            WHEN PostCountRank <= 10 THEN 'Top Posters'
            WHEN UpVotesRank <= 10 THEN 'Top Upvoted'
            WHEN DownVotesRank <= 10 THEN 'Top Downvoted'
            ELSE 'Regular Users'
        END AS UserGroup
    FROM 
        TopUsers
)
SELECT 
    UserGroup,
    COUNT(UserId) AS UserCount,
    AVG(PostCount) AS AvgPosts,
    AVG(TotalUpVotes) AS AvgUpVotes,
    AVG(TotalDownVotes) AS AvgDownVotes,
    AVG(CommentCount) AS AvgComments
FROM 
    UserHighlights
GROUP BY 
    UserGroup
ORDER BY 
    UserCount DESC;
