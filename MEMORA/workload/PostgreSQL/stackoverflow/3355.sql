WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
        INNER JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.UpVotes,
        UA.DownVotes,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS UserRank
    FROM 
        UserActivity UA
)
SELECT 
    Ru.UserId,
    Ru.DisplayName,
    Ru.Reputation,
    Ru.PostCount,
    Ru.UpVotes - Ru.DownVotes AS NetVotes,
    Pt.TagName,
    CASE 
        WHEN Ru.PostCount > 10 THEN 'Active Contributor'
        ELSE 'Newcomer'
    END AS ContributorStatus
FROM 
    RankedUsers Ru
    LEFT JOIN PopularTags Pt ON Ru.PostCount = Pt.PostCount
WHERE 
    Ru.UserRank <= 100
ORDER BY 
    Ru.Reputation DESC, 
    Pt.PostCount DESC;
