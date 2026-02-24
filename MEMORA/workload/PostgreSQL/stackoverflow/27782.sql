
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsVotedOn
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
), 

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostsVotedOn,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY DownVotes DESC) AS DownVoteRank
    FROM 
        UserVoteSummary
)

SELECT 
    T.DisplayName,
    T.UpVotes,
    T.DownVotes,
    T.PostsVotedOn,
    PH.Location,
    PH.WebsiteUrl,
    PH.Reputation,
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    TopUsers T
JOIN 
    Users PH ON T.UserId = PH.Id
LEFT JOIN 
    Posts P ON PH.Id = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    T.UpVoteRank <= 10 OR T.DownVoteRank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.UpVotes, T.DownVotes, T.PostsVotedOn, 
    PH.Location, PH.WebsiteUrl, PH.Reputation, PT.Name
ORDER BY 
    T.UpVotes DESC, T.DownVotes ASC;
