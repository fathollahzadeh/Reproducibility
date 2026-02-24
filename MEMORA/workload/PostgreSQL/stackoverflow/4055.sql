
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
), PostHistorySummary AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS EditComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        PH.UserId, PH.PostId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalAnswers,
    US.TotalBounties,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.EditComments,
    (SELECT STRING_AGG(TagName, ', ') FROM TopTags) AS PopularTags
FROM 
    UserStatistics US
LEFT JOIN 
    PostHistorySummary PHS ON US.UserId = PHS.UserId
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.TotalPosts DESC, US.Reputation DESC;
