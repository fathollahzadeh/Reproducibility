WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VT.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AcceptedAnswerId,
        ARRAY_AGG(DISTINCT TRIM(T.TagName)) AS Tags,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score
    FROM 
        Posts P
        LEFT JOIN UNNEST(string_to_array(P.Tags, '>')) AS TagTag(TagName) ON true
        LEFT JOIN Tags T ON T.TagName = TRIM(TagTag.TagName)
    GROUP BY 
        P.Id, P.Title, P.AcceptedAnswerId, P.CreationDate, P.ViewCount, P.AnswerCount, P.Score
),
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        MAX(CA.CreationDate) AS LastActivityDate,
        COUNT(CM.Id) AS CommentCount,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Posts P
        LEFT JOIN Comments CM ON P.Id = CM.PostId
        LEFT JOIN PostHistory PH ON P.Id = PH.PostId
        LEFT JOIN Posts CA ON P.AcceptedAnswerId = CA.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    U.Favorites,
    P.Title,
    P.Tags,
    P.ViewCount,
    P.AnswerCount,
    P.Score,
    R.LastActivityDate,
    R.CommentCount,
    R.HistoryCount
FROM 
    UserVoteStats U
    JOIN PostTagStats P ON U.UserId = P.AcceptedAnswerId
    JOIN RecentActivity R ON P.PostId = R.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC, R.LastActivityDate DESC
LIMIT 100;