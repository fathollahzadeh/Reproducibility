WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(UPV.VoteCount) AS TotalUpVotes,
        SUM(DNV.VoteCount) AS TotalDownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers,
        AVG(U.Reputation) AS AvgReputationOfPostOwners
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN (
        SELECT 
            V.PostId,
            COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS VoteCount
        FROM Votes V
        GROUP BY V.PostId
    ) UPV ON P.Id = UPV.PostId
    LEFT JOIN (
        SELECT 
            V.PostId,
            COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS VoteCount
        FROM Votes V
        GROUP BY V.PostId
    ) DNV ON P.Id = DNV.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY T.TagName
),
RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalAnswers,
        AvgReputationOfPostOwners,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank,
        DENSE_RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank,
        DENSE_RANK() OVER (ORDER BY TotalDownVotes DESC) AS DownVoteRank
    FROM TagStats
)
SELECT 
    RT.TagName,
    RT.PostCount,
    RT.TotalUpVotes,
    RT.TotalDownVotes,
    RT.TotalAnswers,
    RT.AvgReputationOfPostOwners,
    RT.PostCountRank,
    RT.UpVoteRank,
    RT.DownVoteRank
FROM RankedTags RT
WHERE RT.PostCount > 5
ORDER BY RT.PostCount DESC, RT.TotalUpVotes DESC;
