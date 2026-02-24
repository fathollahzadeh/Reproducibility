WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(VoteTypeCounts.UpVotes) AS TotalUpVotes,
        SUM(VoteTypeCounts.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (
            SELECT 
                V.UserId,
                P.Id AS PostId,
                SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
            FROM 
                Votes V
            JOIN 
                VoteTypes VT ON V.VoteTypeId = VT.Id
            JOIN 
                Posts P ON V.PostId = P.Id
            GROUP BY 
                V.UserId, P.Id
        ) VoteTypeCounts ON U.Id = VoteTypeCounts.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    UserPostStats
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;