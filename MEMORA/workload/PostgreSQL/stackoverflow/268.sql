
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounty,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalBounty DESC, UpVotes DESC) AS UserRank
    FROM 
        UserActivity
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(P.Tags, '<>')) AS TagName) T ON TRUE
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.AnswerCount
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalBounty,
    U.UpVotes,
    U.DownVotes,
    R.UserRank,
    A.PostId,
    A.Title,
    A.ViewCount,
    A.AnswerCount,
    A.LastEditDate,
    A.Tags
FROM 
    RankedUsers R
JOIN 
    UserActivity U ON R.UserId = U.UserId
LEFT JOIN 
    ActivePosts A ON A.LastEditDate = (SELECT MAX(LastEditDate) FROM ActivePosts AP WHERE AP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.UserId))
WHERE 
    R.UserRank <= 10
ORDER BY 
    U.TotalBounty DESC, U.UpVotes DESC;
