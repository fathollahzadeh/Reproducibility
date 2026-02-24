
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        (UpVotes - DownVotes) AS Score,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.Score,
    T.Rank,
    (SELECT STRING_AGG(TT.TagName, ', ') 
     FROM Tags TT 
     WHERE TT.Id IN (SELECT DISTINCT CAST(UNNEST(string_to_array(P.Tags, '<>')) AS INTEGER))
                    AND P.OwnerUserId IS NOT NULL
                    AND P.AnswerCount > 0) AS Tags
FROM 
    TopUsers T
JOIN 
    Posts P ON T.UserId = P.OwnerUserId
WHERE 
    T.Rank <= 10
AND 
    EXISTS (SELECT 1 FROM PostHistory PH 
            WHERE PH.PostId = P.Id 
            AND PH.PostHistoryTypeId IN (10, 12) 
            AND PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
ORDER BY 
    T.Score DESC
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;
