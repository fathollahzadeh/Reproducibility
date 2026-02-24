WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        P.AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        Author,
        Score,
        ViewCount,
        UpVotes,
        DownVotes,
        AnswerCount,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        RecentPosts
),
TopPosts AS (
    SELECT 
        P.*,
        CASE 
            WHEN ScoreRank <= 10 THEN 'Top 10 Posts'
            ELSE 'Other Posts' 
        END AS RankingCategory
    FROM 
        PostStats P
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CH.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CH ON PH.Comment::int = CH.Id 
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    T.PostId,
    T.Title,
    T.Author,
    T.Score,
    T.ViewCount,
    T.UpVotes,
    T.DownVotes,
    T.AnswerCount,
    T.RankingCategory,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason
FROM 
    TopPosts T
LEFT JOIN 
    ClosedPosts CP ON T.PostId = CP.PostId
ORDER BY 
    T.Score DESC, 
    T.ViewCount DESC;