WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentVotes AS (
    SELECT 
        V.UserId, 
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VT.Name IS NULL THEN 1 ELSE 0 END) AS NullVotes
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY V.UserId
),
CombinedData AS (
    SELECT 
        U.DisplayName,
        COALESCE(UPC.PostCount, 0) AS TotalPosts,
        COALESCE(UPC.QuestionCount, 0) AS TotalQuestions,
        COALESCE(UPC.AnswerCount, 0) AS TotalAnswers,
        COALESCE(RV.VoteCount, 0) AS TotalVotes,
        COALESCE(RV.UpVotes, 0) AS UpVoteCount,
        COALESCE(RV.DownVotes, 0) AS DownVoteCount,
        COALESCE(RV.NullVotes, 0) AS NullVoteCount
    FROM Users U
    LEFT JOIN UserPostCounts UPC ON U.Id = UPC.UserId
    LEFT JOIN RecentVotes RV ON U.Id = RV.UserId
)
SELECT 
    CD.DisplayName, 
    CD.TotalPosts, 
    CD.TotalQuestions, 
    CD.TotalAnswers, 
    CD.TotalVotes, 
    CD.UpVoteCount, 
    CD.DownVoteCount, 
    CD.NullVoteCount,
    ROW_NUMBER() OVER (ORDER BY CD.TotalPosts DESC) AS Rank
FROM CombinedData CD
WHERE CD.TotalPosts > 0
ORDER BY CD.TotalPosts DESC, CD.TotalVotes DESC
LIMIT 10;