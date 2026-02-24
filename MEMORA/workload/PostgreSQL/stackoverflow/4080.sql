WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostAnswerCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswerCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2 
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UAC.UpVotes, 0) AS UpVotes,
        COALESCE(UAC.DownVotes, 0) AS DownVotes,
        COALESCE(PAC.AnswerCount, 0) AS Answers,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY COALESCE(UAC.UpVotes, 0) DESC, U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserVoteCounts UAC ON U.Id = UAC.UserId
    LEFT JOIN 
        PostAnswerCounts PAC ON U.Id = PAC.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.UpVotes,
    TU.DownVotes,
    TU.Answers,
    TU.Reputation,
    CASE 
        WHEN TU.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    TopUsers TU
WHERE 
    TU.Reputation > 100
ORDER BY 
    TU.UpVotes DESC, 
    TU.Answers DESC;